//
//  ViewController.m
//  unordinary-final
//
//  Created by d0gg3r on 21/11/2020.
//  Copyright © 2020 bios. All rights reserved.
//

#import "ViewController.h"
#import "DBManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
@interface DBHolder : NSObject
+(DBManager*)manager;
@end
@implementation DBHolder

+(DBManager*)manager {
    static DBManager* mgr = nil;
    if (mgr == nil){
        mgr = [[DBManager alloc]init];
    }
    return mgr;
}

@end
@interface FindCaseController : UITableViewController<UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    BOOL currentlyEditing;
}
@property NSMutableArray<NSDictionary*>* cases;
@end
@implementation FindCaseController
-(void)viewDidLoad{
    if (!self.cases){
        self.cases = [[NSMutableDictionary alloc]init];
        NSMutableDictionary* data = [DBHolder.manager getResultFromQuery:"SELECT rowid, a.* FROM cases a"].mutableCopy;
        [data removeObjectForKey:@"result"];
        NSLog(@"%@", data);
        for (NSDictionary* caseResult in data.allValues){
            NSLog(@"%@", caseResult);
            [self.cases addObject:caseResult];
        }
        NSLog(@"%@", self.cases);
    }
    self.tableView.dataSource = self;
    currentlyEditing = NO;
}
- (IBAction)editTapped:(id)sender {
    if (currentlyEditing){
        UIBarButtonItem* editing = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTapped:)];
        self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItems[0], editing];
        [self.tableView setEditing:NO animated:YES];
        currentlyEditing = NO;
    } else {
        UIBarButtonItem* stopEditing = [[UIBarButtonItem alloc]initWithTitle:@"Stop editing" style:UIBarButtonItemStylePlain target:self action:@selector(editTapped:)];
        self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItems[0], stopEditing];
        [self.tableView setEditing:YES animated:YES];
        currentlyEditing = YES;
    }
}
- (IBAction)searchTapped:(id)sender{
    
}

- (IBAction)doneTapped:(id)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}


// DataSource and Delegates
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete){
        [self.cases removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadData];
    }
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [self.cases count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellIdentifier = @"CaseCell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    NSString* imagesString = (NSString*)[self.cases[indexPath.row]objectForKey:@"attachments"];
    NSURL* imageURL = [NSURL URLWithString:[imagesString isEqualToString:@""] ? imagesString : [imagesString componentsSeparatedByString:@";"].firstObject];
    cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
    cell.textLabel.text = ((NSString*)[self.cases[indexPath.row] objectForKey:@"name"]);
    return cell;
}
@end
@interface AttachmentsController : UITableViewController<UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    BOOL currentlyEditing;
}
@property NSMutableArray<NSURL*>* attachments;
@end
@implementation AttachmentsController
-(void)viewDidLoad{
    self.tableView.dataSource = self;
    if (!self.attachments){
        self.attachments = [[NSMutableArray alloc]init];
    }
    currentlyEditing = NO;
}
- (IBAction)editTapped:(id)sender {
    if (currentlyEditing){
        UIBarButtonItem* editing = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTapped:)];
        self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItems[0], editing];
        [self.tableView setEditing:NO animated:YES];
        currentlyEditing = NO;
    } else {
        UIBarButtonItem* stopEditing = [[UIBarButtonItem alloc]initWithTitle:@"Stop editing" style:UIBarButtonItemStylePlain target:self action:@selector(editTapped:)];
        self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItems[0], stopEditing];
        [self.tableView setEditing:YES animated:YES];
        currentlyEditing = YES;
    }
}
- (IBAction)addTapped:(id)sender {
    UIImagePickerController* picker = [[UIImagePickerController alloc]init];
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationCurrentContext;
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    picker.mediaTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4, (NSString*)kUTTypeImage];
    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)doneTapped:(id)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}


// DataSource and Delegates
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete){
        [self.attachments removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadData];
    }
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [self.attachments count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellIdentifier = @"AttachmentCell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.attachments[indexPath.row]]];
    cell.textLabel.text = self.attachments[indexPath.row].lastPathComponent;
    return cell;
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSURL* videoURL = [info.allKeys containsObject:UIImagePickerControllerImageURL] ? [info objectForKey:UIImagePickerControllerImageURL] : [info objectForKey:UIImagePickerControllerMediaURL];
    [self.attachments addObject:videoURL];
    NSIndexPath* path = [NSIndexPath indexPathForRow:self.attachments.count-1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
    [picker dismissViewControllerAnimated:YES completion:nil];
    }

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end

@interface CreateCaseController : UIViewController<UITextViewDelegate, UITextFieldDelegate> {
    BOOL currentlyEditing;
    UIBarButtonItem* cancelBarButton;
    UIBarButtonItem* saveBarButton;
}
@property (weak, nonatomic) IBOutlet UITextView *notesTextView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSegmented;
@property (weak, nonatomic) IBOutlet UIDatePicker *birthDatePicker;
@property UINavigationController* attachmentController;
@end

@implementation CreateCaseController
- (void)viewDidLoad{
    currentlyEditing = NO;
    [self.notesTextView setDelegate:self];
    [self.nameTextField setDelegate:self];
}
- (IBAction)leftBarButtonTapped:(id)sender {
    if (currentlyEditing){
        currentlyEditing = NO;
        [self.navigationItem setLeftBarButtonItem:cancelBarButton];
        [self.navigationItem setRightBarButtonItem:saveBarButton];
        [self.notesTextView endEditing:YES];
        [self.nameTextField endEditing:YES];
        if ([self.notesTextView.text isEqualToString:@""]){
            self.notesTextView.text = @"Type your notes here";
        }
    } else {
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    }
}
- (IBAction)rightBarButtonTapped:(id)sender {
    if (currentlyEditing == NO){
        //(name, gender, birthdate, attachments, notes, tags)
        AttachmentsController* controller = (AttachmentsController*)self.attachmentController.viewControllers.firstObject;
        NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
        formatter.dateFormat = @"yyyy-MM-dd";
        NSDictionary* data = @{@"name": self.nameTextField.text, @"gender": @(self.genderSegmented.selectedSegmentIndex), @"birthdate": [formatter stringFromDate:self.birthDatePicker.date], @"attachments": controller ? [controller.attachments componentsJoinedByString:@";"]: @"", @"notes": [self.notesTextView.text isEqualToString:@"Type your notes here"] ? @"" : self.notesTextView.text, @"tags": @[]};
        const char* hash = [[DBHolder manager]addCaseWithData:data];
        if (hash == NULL) NSLog(@"Error creating case");
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    }
}
- (IBAction)addAttachmentTapped:(id)sender {
    UINavigationController* vc;
    if (!self.attachmentController){
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        vc = [sb instantiateViewControllerWithIdentifier:@"AttachmentsNavigation"];
    } else vc = self.attachmentController;
    [self presentViewController:vc animated:YES completion:nil];
    self.attachmentController = vc;
}
- (void)textViewDidBeginEditing:(UITextView *)textView{
    currentlyEditing = YES;
    if ([textView.text isEqualToString:@"Type your notes here"]) {
        textView.text = @"";
    }
    cancelBarButton = self.navigationItem.leftBarButtonItem;
    saveBarButton = self.navigationItem.rightBarButtonItem;
    UIBarButtonItem* left = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(leftBarButtonTapped:)];
    UIBarButtonItem* right = [[UIBarButtonItem alloc]initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonTapped:)];
    [self.navigationItem setLeftBarButtonItem:left];
    [self.navigationItem setRightBarButtonItem:right];
}

@end

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

// Welcome screen
- (IBAction)createCaseTextTap:(id)sender {
    UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController* vc = [sb instantiateViewControllerWithIdentifier:@"CreateCaseNavigation"];
    [self presentViewController:vc animated:YES completion:nil];
}
- (IBAction)findCaseTextTap:(id)sender {
    UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController* vc = [sb instantiateViewControllerWithIdentifier:@"FindCaseNavigation"];
    [self presentViewController:vc animated:YES completion:nil];
}

@end









































